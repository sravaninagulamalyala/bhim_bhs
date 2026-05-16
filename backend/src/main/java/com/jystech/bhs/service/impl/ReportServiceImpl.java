package com.jystech.bhs.service.impl;

import com.jystech.bhs.entity.Family;
import com.jystech.bhs.entity.TransactionRecord;
import com.jystech.bhs.entity.TransactionType;
import com.jystech.bhs.repository.FamilyRepository;
import com.jystech.bhs.repository.MemberRepository;
import com.jystech.bhs.repository.TransactionRepository;
import com.jystech.bhs.service.ReportService;
import lombok.RequiredArgsConstructor;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.*;

@Service
@RequiredArgsConstructor
public class ReportServiceImpl implements ReportService {
    private final FamilyRepository familyRepository;
    private final MemberRepository memberRepository;
    private final TransactionRepository transactionRepository;

    @Override
    public Map<String, Object> familyMemberCount() {
        return Map.of("activeFamilyCount", familyRepository.countByActiveTrue(), "activeMemberCount", memberRepository.countByActiveTrue());
    }

    @Override
    public Map<String, Object> monthlyContribution(YearMonth month) {
        LocalDate start = month.atDay(1);
        LocalDate end = month.atEndOfMonth();
        BigDecimal total = transactionRepository.findByTransactionDateBetweenOrderByTransactionDateDesc(start, end).stream()
                .filter(t -> t.getTransactionType() == TransactionType.CREDIT)
                .map(TransactionRecord::getAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        return Map.of("month", month.toString(), "totalContribution", total);
    }

    @Override
    public Map<String, Object> contributedFamilies(YearMonth month) {
        List<Long> ids = contributedIds(month);
        return Map.of("month", month.toString(), "count", ids.size(), "familyIds", ids);
    }

    @Override
    public Map<String, Object> nonContributedFamilies(YearMonth month) {
        Set<Long> contributed = new HashSet<>(contributedIds(month));
        List<Family> families = familyRepository.findByActiveTrue().stream().filter(f -> !contributed.contains(f.getId())).toList();
        return Map.of("month", month.toString(), "count", families.size(), "families", families);
    }

    @Override
    public Map<String, Object> heatmap(YearMonth month) {
        Map<Integer, BigDecimal> dayTotals = new TreeMap<>();
        transactionRepository.findByTransactionDateBetweenOrderByTransactionDateDesc(month.atDay(1), month.atEndOfMonth()).stream()
                .filter(t -> t.getTransactionType() == TransactionType.CREDIT)
                .forEach(t -> dayTotals.merge(t.getTransactionDate().getDayOfMonth(), t.getAmount(), BigDecimal::add));
        return Map.of("month", month.toString(), "dailyCredits", dayTotals);
    }

    @Override
    public ByteArrayInputStream download(String type, YearMonth month) {
        List<Family> families = familiesForType(type, month);
        try (Workbook workbook = new XSSFWorkbook(); ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            Sheet sheet = workbook.createSheet("Report");
            Row header = sheet.createRow(0);
            header.createCell(0).setCellValue("Family ID");
            header.createCell(1).setCellValue("Family Code");
            header.createCell(2).setCellValue("House No");
            header.createCell(3).setCellValue("Area");
            header.createCell(4).setCellValue("Address");
            for (int i = 0; i < families.size(); i++) {
                Family family = families.get(i);
                Row row = sheet.createRow(i + 1);
                row.createCell(0).setCellValue(family.getId());
                row.createCell(1).setCellValue(family.getFamilyCode());
                row.createCell(2).setCellValue(family.getHouseNo());
                row.createCell(3).setCellValue(family.getArea());
                row.createCell(4).setCellValue(family.getAddress());
            }
            for (int i = 0; i < 5; i++) sheet.autoSizeColumn(i);
            workbook.write(out);
            return new ByteArrayInputStream(out.toByteArray());
        } catch (Exception ex) {
            throw new IllegalStateException("Unable to generate report", ex);
        }
    }

    private List<Long> contributedIds(YearMonth month) {
        return transactionRepository.contributedFamilyIds(month.atDay(1), month.atEndOfMonth());
    }

    private List<Family> familiesForType(String type, YearMonth month) {
        String value = type == null ? "ALL" : type.toUpperCase(Locale.ROOT);
        List<Family> all = familyRepository.findByActiveTrue();
        if ("ALL".equals(value)) return all;
        Set<Long> contributed = new HashSet<>(contributedIds(month));
        if ("CONTRIBUTED".equals(value)) return all.stream().filter(f -> contributed.contains(f.getId())).toList();
        return all.stream().filter(f -> !contributed.contains(f.getId())).toList();
    }
}
