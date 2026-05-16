package com.jystech.bhs.service.impl;

import com.jystech.bhs.audit.AuditService;
import com.jystech.bhs.dto.TransactionDtos;
import com.jystech.bhs.entity.TransactionRecord;
import com.jystech.bhs.entity.TransactionType;
import com.jystech.bhs.exception.BadRequestException;
import com.jystech.bhs.repository.TransactionRepository;
import com.jystech.bhs.service.TransactionService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.YearMonth;
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
        TransactionRecord record = new TransactionRecord();
        record.setTransactionDate(request.transactionDate() == null ? LocalDate.now() : request.transactionDate());
        record.setFamilyId(request.familyId());
        record.setMemberId(request.memberId());
        record.setTransactionType(request.transactionType());
        record.setAmount(request.amount());
        record.setRemarks(request.remarks());
        record.setCreatedBy(SecurityContextHolder.getContext().getAuthentication().getName());
        TransactionRecord saved = transactionRepository.save(record);
        auditService.log("CREATE", "TRANSACTION", request.transactionType() + " transaction id: " + saved.getId());
        return saved;
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
}
