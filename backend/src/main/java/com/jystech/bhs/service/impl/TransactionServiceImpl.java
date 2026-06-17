package com.jystech.bhs.service.impl;

import com.jystech.bhs.audit.AuditService;
import com.jystech.bhs.dto.TransactionDtos;
import com.jystech.bhs.entity.TransactionRecord;
import com.jystech.bhs.entity.TransactionType;
import com.jystech.bhs.exception.BadRequestException;
import com.jystech.bhs.repository.TransactionRepository;
import com.jystech.bhs.service.TransactionService;
import lombok.RequiredArgsConstructor;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class TransactionServiceImpl implements TransactionService {
    private final TransactionRepository transactionRepository;
    private final AuditService auditService;

    @Override
    public TransactionRecord create(TransactionDtos.TransactionRequest request) {
        if (request.amount() == null || request.amount().compareTo(BigDecimal.ZERO) <= 0) {
            throw new BadRequestException("Amount must be greater than zero");
        }
        if (request.transactionType() == null) {
            throw new BadRequestException("Transaction type is required");
        }
        TransactionRecord record = new TransactionRecord();
        record.setTransactionDate(request.transactionDate() == null ? LocalDate.now() : request.transactionDate());
        record.setFamilyId(request.familyId());
        record.setMemberId(request.memberId());
        record.setTransactionType(request.transactionType());
        record.setAmount(request.amount());
        record.setPurpose(clean(request.purpose()));
        record.setRemarks(request.remarks());
        record.setCreatedBy(SecurityContextHolder.getContext().getAuthentication().getName());
        TransactionRecord saved = transactionRepository.save(record);
        recalculateBalances();
        auditService.log("CREATE", "TRANSACTION", request.transactionType() + " transaction id: " + saved.getId());
        return transactionRepository.findById(saved.getId()).orElse(saved);
    }

    @Override
    public List<TransactionRecord> all() {
        return transactionRepository.findAllByOrderByTransactionDateDesc();
    }

    @Override
    public TransactionDtos.BalanceResponse balance() {
        BigDecimal credit = transactionRepository.sumByType(TransactionType.CREDIT);
        BigDecimal debit = transactionRepository.sumByType(TransactionType.DEBIT);
        return new TransactionDtos.BalanceResponse(credit, debit, credit.subtract(debit));
    }

    @Override
    public Map<String, Object> monthlySummary(YearMonth month) {
        LocalDate start = month.atDay(1);
        LocalDate end = month.atEndOfMonth();
        BigDecimal credit = BigDecimal.ZERO;
        BigDecimal debit = BigDecimal.ZERO;
        for (TransactionRecord record : transactionRepository.findByTransactionDateBetweenOrderByTransactionDateDesc(start, end)) {
            if (record.getTransactionType() == TransactionType.CREDIT) credit = credit.add(record.getAmount());
            if (record.getTransactionType() == TransactionType.DEBIT) debit = debit.add(record.getAmount());
        }
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("month", month.toString());
        map.put("totalCredit", credit);
        map.put("totalDebit", debit);
        map.put("balance", credit.subtract(debit));
        return map;
    }

    @Override
    public TransactionDtos.MonthlyStatementResponse monthlyStatement(YearMonth month) {
        LocalDate start = month.atDay(1);
        LocalDate end = month.atEndOfMonth();
        BigDecimal opening = balanceBefore(start);
        BigDecimal running = opening;
        BigDecimal credit = BigDecimal.ZERO;
        BigDecimal debit = BigDecimal.ZERO;
        List<TransactionDtos.StatementTransaction> rows = new ArrayList<>();
        for (TransactionRecord record : transactionRepository.findByTransactionDateBetweenOrderByTransactionDateAscIdAsc(start, end)) {
            BigDecimal creditAmount = record.getTransactionType() == TransactionType.CREDIT ? record.getAmount() : BigDecimal.ZERO;
            BigDecimal debitAmount = record.getTransactionType() == TransactionType.DEBIT ? record.getAmount() : BigDecimal.ZERO;
            running = running.add(creditAmount).subtract(debitAmount);
            credit = credit.add(creditAmount);
            debit = debit.add(debitAmount);
            BigDecimal balanceAfter = record.getBalanceAfterTransaction() == null ? running : record.getBalanceAfterTransaction();
            rows.add(new TransactionDtos.StatementTransaction(
                    record.getId(),
                    record.getTransactionDate(),
                    record.getTransactionType(),
                    record.getPurpose(),
                    record.getRemarks(),
                    creditAmount,
                    debitAmount,
                    balanceAfter,
                    record.getCreatedBy()));
        }
        BigDecimal totalMovement = credit.add(debit);
        BigDecimal creditPercentage = percentage(credit, totalMovement);
        BigDecimal debitPercentage = percentage(debit, totalMovement);
        return new TransactionDtos.MonthlyStatementResponse(month.toString(), opening, credit, debit,
                opening.add(credit).subtract(debit), creditPercentage, debitPercentage, rows);
    }

    @Override
    public ByteArrayInputStream downloadStatement(YearMonth month) {
        TransactionDtos.MonthlyStatementResponse statement = monthlyStatement(month);
        try (Workbook workbook = new XSSFWorkbook(); ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            Sheet sheet = workbook.createSheet("Statement");
            writeHeader(sheet.createRow(0), "S.No", "Date", "Transaction Type", "Purpose", "Remarks",
                    "Credit Amount", "Debit Amount", "Balance After Transaction", "Created By");
            List<TransactionDtos.StatementTransaction> rows = statement.transactions();
            for (int i = 0; i < rows.size(); i++) {
                TransactionDtos.StatementTransaction item = rows.get(i);
                Row row = sheet.createRow(i + 1);
                row.createCell(0).setCellValue(i + 1);
                row.createCell(1).setCellValue(item.transactionDate() == null ? "" : item.transactionDate().toString());
                row.createCell(2).setCellValue(item.transactionType() == null ? "" : item.transactionType().name());
                row.createCell(3).setCellValue(text(item.purpose()));
                row.createCell(4).setCellValue(text(item.remarks()));
                row.createCell(5).setCellValue(item.creditAmount() == null ? 0 : item.creditAmount().doubleValue());
                row.createCell(6).setCellValue(item.debitAmount() == null ? 0 : item.debitAmount().doubleValue());
                row.createCell(7).setCellValue(item.balanceAfterTransaction() == null ? 0 : item.balanceAfterTransaction().doubleValue());
                row.createCell(8).setCellValue(text(item.createdBy()));
            }
            for (int i = 0; i < 9; i++) sheet.autoSizeColumn(i);
            workbook.write(out);
            return new ByteArrayInputStream(out.toByteArray());
        } catch (Exception ex) {
            throw new IllegalStateException("Unable to generate transaction statement", ex);
        }
    }

    private void recalculateBalances() {
        BigDecimal running = BigDecimal.ZERO;
        for (TransactionRecord record : transactionRepository.findAllByOrderByTransactionDateAscIdAsc()) {
            if (record.getTransactionType() == TransactionType.CREDIT) running = running.add(record.getAmount());
            if (record.getTransactionType() == TransactionType.DEBIT) running = running.subtract(record.getAmount());
            record.setBalanceAfterTransaction(running);
            record.setUpdatedAt(LocalDateTime.now());
            transactionRepository.save(record);
        }
    }

    private BigDecimal balanceBefore(LocalDate date) {
        BigDecimal running = BigDecimal.ZERO;
        for (TransactionRecord record : transactionRepository.findAllByOrderByTransactionDateAscIdAsc()) {
            if (!record.getTransactionDate().isBefore(date)) break;
            if (record.getTransactionType() == TransactionType.CREDIT) running = running.add(record.getAmount());
            if (record.getTransactionType() == TransactionType.DEBIT) running = running.subtract(record.getAmount());
        }
        return running;
    }

    private BigDecimal percentage(BigDecimal value, BigDecimal total) {
        if (total.compareTo(BigDecimal.ZERO) == 0) return BigDecimal.ZERO;
        return value.multiply(BigDecimal.valueOf(100)).divide(total, 2, RoundingMode.HALF_UP);
    }

    private void writeHeader(Row header, String... labels) {
        for (int i = 0; i < labels.length; i++) header.createCell(i).setCellValue(labels[i]);
    }

    private String clean(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    private String text(String value) {
        return value == null ? "" : value;
    }
}
