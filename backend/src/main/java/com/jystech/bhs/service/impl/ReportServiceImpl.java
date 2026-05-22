package com.jystech.bhs.service.impl;

import com.jystech.bhs.entity.Family;
import com.jystech.bhs.entity.Member;
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
        Set<Long> contributed = new HashSet<>(contributedIds(month));
        try (Workbook workbook = new XSSFWorkbook(); ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            Sheet sheet = workbook.createSheet("Report");
            writeHeader(sheet.createRow(0), "S.No", "Family Head Name", "Family Code", "House No", "Area", "Family Member Names",
                    "Mobile Numbers", "Contribution Status", "Contribution Amount", "Month", "Remarks");
            for (int i = 0; i < families.size(); i++) {
                Family family = families.get(i);
                List<Member> members = memberRepository.findByFamilyIdAndActiveTrue(family.getId());
                Member head = familyHead(family, members);
                BigDecimal amount = transactionRepository.contributionAmount(family.getId(), month.atDay(1), month.atEndOfMonth());
                Row row = sheet.createRow(i + 1);
                row.createCell(0).setCellValue(i + 1);
                row.createCell(1).setCellValue(head == null ? "" : head.getFullName());
                row.createCell(2).setCellValue(text(family.getFamilyCode()));
                row.createCell(3).setCellValue(text(family.getHouseNo()));
                row.createCell(4).setCellValue(text(family.getArea()));
                row.createCell(5).setCellValue(names(members));
                row.createCell(6).setCellValue(mobiles(members));
                row.createCell(7).setCellValue(contributed.contains(family.getId()) ? "Contributed" : "Non-Contributed");
                row.createCell(8).setCellValue(amount == null ? 0 : amount.doubleValue());
                row.createCell(9).setCellValue(month.toString());
                row.createCell(10).setCellValue(text(family.getAddress()));
            }
            for (int i = 0; i < 11; i++) sheet.autoSizeColumn(i);
            workbook.write(out);
            return new ByteArrayInputStream(out.toByteArray());
        } catch (Exception ex) {
            throw new IllegalStateException("Unable to generate report", ex);
        }
    }

    @Override
    public ByteArrayInputStream downloadMembers() {
        try (Workbook workbook = new XSSFWorkbook(); ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            Sheet sheet = workbook.createSheet("Members");
            writeHeader(sheet.createRow(0), "S.No", "Member Name", "Father/Husband Name", "Age", "Sex", "Mobile Number",
                    "Alternate Mobile Number", "Family Head Name", "Family Code", "House No", "Area", "Address", "Active Status");
            List<Member> members = memberRepository.findAll();
            for (int i = 0; i < members.size(); i++) {
                Member member = members.get(i);
                Family family = member.getFamilyId() == null ? null : familyRepository.findById(member.getFamilyId()).orElse(null);
                List<Member> familyMembers = family == null ? List.of() : memberRepository.findByFamilyIdAndActiveTrue(family.getId());
                Member head = family == null ? null : familyHead(family, familyMembers);
                Row row = sheet.createRow(i + 1);
                row.createCell(0).setCellValue(i + 1);
                row.createCell(1).setCellValue(text(member.getFullName()));
                row.createCell(2).setCellValue(text(member.getFatherOrHusbandName()));
                if (member.getAge() != null) row.createCell(3).setCellValue(member.getAge()); else row.createCell(3).setCellValue("");
                row.createCell(4).setCellValue(text(member.getSex()));
                row.createCell(5).setCellValue(text(member.getMobileNo()));
                row.createCell(6).setCellValue(text(member.getAlternateMobileNo()));
                row.createCell(7).setCellValue(head == null ? "" : text(head.getFullName()));
                row.createCell(8).setCellValue(family == null ? "" : text(family.getFamilyCode()));
                row.createCell(9).setCellValue(text(member.getHouseNo()));
                row.createCell(10).setCellValue(text(member.getArea()));
                row.createCell(11).setCellValue(text(member.getAddress()));
                row.createCell(12).setCellValue(member.isActive() ? "Active" : "Inactive");
            }
            for (int i = 0; i < 13; i++) sheet.autoSizeColumn(i);
            workbook.write(out);
            return new ByteArrayInputStream(out.toByteArray());
        } catch (Exception ex) {
            throw new IllegalStateException("Unable to generate members report", ex);
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

    private void writeHeader(Row header, String... labels) {
        for (int i = 0; i < labels.length; i++) header.createCell(i).setCellValue(labels[i]);
    }

    private Member familyHead(Family family, List<Member> members) {
        if (family.getPrimaryMemberId() != null) {
            for (Member member : members) {
                if (family.getPrimaryMemberId().equals(member.getId())) return member;
            }
        }
        return members.stream().filter(member -> member.getAge() != null).max(Comparator.comparing(Member::getAge))
                .orElseGet(() -> members.stream().min(Comparator.comparing(Member::getId, Comparator.nullsLast(Long::compareTo))).orElse(null));
    }

    private String names(List<Member> members) {
        return members.stream().map(Member::getFullName).filter(value -> value != null && !value.isBlank()).reduce((a, b) -> a + ", " + b).orElse("");
    }

    private String mobiles(List<Member> members) {
        return members.stream()
                .flatMap(member -> java.util.stream.Stream.of(member.getMobileNo(), member.getAlternateMobileNo()))
                .filter(value -> value != null && !value.isBlank())
                .distinct()
                .reduce((a, b) -> a + ", " + b)
                .orElse("");
    }

    private String text(String value) {
        return value == null ? "" : value;
    }
}
