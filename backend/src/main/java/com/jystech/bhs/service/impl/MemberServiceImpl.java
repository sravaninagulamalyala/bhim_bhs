package com.jystech.bhs.service.impl;

import com.jystech.bhs.audit.AuditService;
import com.jystech.bhs.dto.MemberDtos;
import com.jystech.bhs.entity.Family;
import com.jystech.bhs.entity.Member;
import com.jystech.bhs.entity.SourceType;
import com.jystech.bhs.exception.BadRequestException;
import com.jystech.bhs.exception.ResourceNotFoundException;
import com.jystech.bhs.mapper.MemberMapper;
import com.jystech.bhs.repository.FamilyRepository;
import com.jystech.bhs.repository.MemberRepository;
import com.jystech.bhs.service.MemberService;
import com.jystech.bhs.util.AddressParser;
import com.jystech.bhs.util.FamilyGroupingUtil;
import com.jystech.bhs.util.MobileNumberParser;
import lombok.RequiredArgsConstructor;
import org.apache.poi.ss.usermodel.*;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.InputStream;
import java.util.*;

@Service
@RequiredArgsConstructor
public class MemberServiceImpl implements MemberService {
    private final MemberRepository memberRepository;
    private final FamilyRepository familyRepository;
    private final FamilyGroupingUtil familyGroupingUtil;
    private final AuditService auditService;

    @Override
    public Object register(MemberDtos.MemberRegistrationRequest request) {
        List<Member> saved = new ArrayList<>();
        if (request.mainMember() != null) saved.add(saveRegisteredMember(request.mainMember(), request.familyId()));
        if (request.familyMembers() != null) {
            for (MemberDtos.MemberInput input : request.familyMembers()) saved.add(saveRegisteredMember(input, saved.isEmpty() ? request.familyId() : saved.get(0).getFamilyId()));
        }
        auditService.log("CREATE", "MEMBER_REGISTRATION", "Registered members count: " + saved.size());
        return saved;
    }

    private Member saveRegisteredMember(MemberDtos.MemberInput input, Long familyId) {
        Member member = MemberMapper.fromRegistration(input);
        Family family = familyId == null
                ? familyGroupingUtil.resolveFamily(member)
                : familyRepository.findById(familyId).orElseThrow(() -> new ResourceNotFoundException("Family not found"));
        member.setFamilyId(family.getId());
        Member saved = memberRepository.save(member);
        if (family.getPrimaryMemberId() == null) {
            family.setPrimaryMemberId(saved.getId());
            familyRepository.save(family);
        }
        return saved;
    }

    @Override
    public List<Member> search(String keyword) {
        String value = keyword == null ? "" : keyword;
        return memberRepository.search(value);
    }

    @Override
    public Member update(Long id, MemberDtos.MemberUpdateRequest request) {
        Member member = memberRepository.findById(id).orElseThrow(() -> new ResourceNotFoundException("Member not found"));
        List<String> updated = new ArrayList<>();
        if (request.firstName() != null) {
            member.setFirstName(request.firstName());
            updated.add("firstName");
        }
        if (request.lastName() != null) {
            member.setLastName(request.lastName());
            updated.add("lastName");
        }
        if (request.fullName() != null && !request.fullName().isBlank()) {
            member.setFullName(request.fullName().trim());
            updated.add("fullName");
        } else if (request.firstName() != null || request.lastName() != null) {
            member.setFullName(((member.getFirstName() == null ? "" : member.getFirstName()) + " " + (member.getLastName() == null ? "" : member.getLastName())).trim());
            updated.add("fullName");
        }
        if (request.fatherOrHusbandName() != null) {
            member.setFatherOrHusbandName(request.fatherOrHusbandName());
            updated.add("fatherOrHusbandName");
        }
        if (request.relationType() != null) {
            member.setRelationType(request.relationType());
            updated.add("relationType");
        }
        if (request.age() != null) {
            member.setAge(request.age());
            updated.add("age");
        }
        if (request.sex() != null) {
            member.setSex(request.sex());
            updated.add("sex");
        }
        if (request.mobileNo() != null) {
            member.setMobileNo(request.mobileNo());
            updated.add("mobileNo");
        }
        if (request.alternateMobileNo() != null) {
            member.setAlternateMobileNo(request.alternateMobileNo());
            updated.add("alternateMobileNo");
        }
        if (request.address() != null) {
            member.setAddress(request.address());
            updated.add("address");
        }
        if (request.houseNo() != null) {
            member.setHouseNo(request.houseNo());
            updated.add("houseNo");
        }
        if (request.area() != null) {
            member.setArea(request.area());
            updated.add("area");
        }
        if (request.active() != null) {
            member.setActive(request.active());
            updated.add("active");
        }
        Member saved = memberRepository.save(member);
        auditService.log("UPDATE_MEMBER", "MEMBER", "Updated memberId: " + id + ", fields: " + String.join(", ", updated));
        return saved;
    }

    @Override
    public List<Member> family(Long memberId) {
        Member member = memberRepository.findById(memberId).orElseThrow(() -> new ResourceNotFoundException("Member not found"));
        return member.getFamilyId() == null ? List.of(member) : memberRepository.findByFamilyIdAndActiveTrue(member.getFamilyId());
    }

    @Override
    public MemberDtos.MemberDetailsResponse details(Long memberId) {
        Member member = memberRepository.findById(memberId).orElseThrow(() -> new ResourceNotFoundException("Member not found"));
        Family family = member.getFamilyId() == null ? null : familyRepository.findById(member.getFamilyId()).orElse(null);
        List<Member> familyMembers = member.getFamilyId() == null ? List.of(member) : memberRepository.findByFamilyIdAndActiveTrue(member.getFamilyId());
        return new MemberDtos.MemberDetailsResponse(member, family, familyMembers);
    }

    @Override
    public Member mapFamily(MemberDtos.MapFamilyRequest request) {
        Member member = memberRepository.findById(request.memberId()).orElseThrow(() -> new ResourceNotFoundException("Member not found"));
        Family family = familyRepository.findById(request.familyId()).orElseThrow(() -> new ResourceNotFoundException("Family not found"));
        member.setFamilyId(family.getId());
        Member saved = memberRepository.save(member);
        auditService.log("UPDATE", "FAMILY_MAPPING", "Mapped member " + member.getId() + " to family " + family.getId());
        return saved;
    }

    @Override
    public Member removeFromFamily(MemberDtos.RemoveFamilyRequest request) {
        if (request.memberId() == null) throw new BadRequestException("Member id is required");
        if (request.familyId() == null) throw new BadRequestException("Family id is required");
        Member member = memberRepository.findById(request.memberId()).orElseThrow(() -> new ResourceNotFoundException("Member not found"));
        Family family = familyRepository.findById(request.familyId()).orElseThrow(() -> new ResourceNotFoundException("Family not found"));
        if (!Objects.equals(member.getFamilyId(), family.getId())) {
            throw new BadRequestException("Member is not mapped to this family");
        }
        member.setFamilyId(null);
        Member saved = memberRepository.save(member);
        if (Objects.equals(family.getPrimaryMemberId(), member.getId())) {
            family.setPrimaryMemberId(null);
            familyRepository.save(family);
        }
        auditService.log("UPDATE", "FAMILY_MAPPING", "Removed member " + member.getId() + " from family " + family.getId());
        return saved;
    }

    @Override
    public Member addToFamily(MemberDtos.AddFamilyRequest request) {
        if (request.memberId() == null) throw new BadRequestException("Member id is required");
        if (request.targetFamilyId() == null) throw new BadRequestException("Target family id is required");
        Member member = memberRepository.findById(request.memberId()).orElseThrow(() -> new ResourceNotFoundException("Member not found"));
        Family family = familyRepository.findById(request.targetFamilyId()).orElseThrow(() -> new ResourceNotFoundException("Family not found"));
        member.setFamilyId(family.getId());
        Member saved = memberRepository.save(member);
        if (family.getPrimaryMemberId() == null) {
            family.setPrimaryMemberId(saved.getId());
            familyRepository.save(family);
        }
        auditService.log("UPDATE", "FAMILY_MAPPING", "Added member " + member.getId() + " to family " + family.getId());
        return saved;
    }

    @Override
    public int uploadExcel(MultipartFile file) {
        if (file == null || file.isEmpty()) throw new BadRequestException("Excel file is required");
        int inserted = 0;
        try (InputStream in = file.getInputStream(); Workbook workbook = WorkbookFactory.create(in)) {
            Sheet sheet = workbook.getSheetAt(0);
            if (sheet == null || sheet.getPhysicalNumberOfRows() < 2) return 0;
            Map<Integer, String> headers = headers(sheet.getRow(0));
            DataFormatter formatter = new DataFormatter();
            for (int i = 1; i <= sheet.getLastRowNum(); i++) {
                Row row = sheet.getRow(i);
                if (row == null) continue;
                Member member = memberFromRow(row, headers, formatter);
                if (member.getFullName() == null || member.getFullName().isBlank()) continue;
                Family family = familyGroupingUtil.resolveFamily(member);
                member.setFamilyId(family.getId());
                Member saved = memberRepository.save(member);
                if (family.getPrimaryMemberId() == null) {
                    family.setPrimaryMemberId(saved.getId());
                    familyRepository.save(family);
                }
                inserted++;
            }
        } catch (Exception ex) {
            throw new BadRequestException("Unable to read Excel file: " + ex.getMessage());
        }
        auditService.log("UPLOAD", "EXCEL", "Uploaded Register-bhs members count: " + inserted);
        return inserted;
    }

    private Map<Integer, String> headers(Row row) {
        Map<Integer, String> headers = new HashMap<>();
        if (row == null) return headers;
        DataFormatter formatter = new DataFormatter();
        for (Cell cell : row) headers.put(cell.getColumnIndex(), normalize(formatter.formatCellValue(cell)));
        return headers;
    }

    private Member memberFromRow(Row row, Map<Integer, String> headers, DataFormatter formatter) {
        Map<String, String> values = new HashMap<>();
        for (Cell cell : row) values.put(headers.getOrDefault(cell.getColumnIndex(), ""), formatter.formatCellValue(cell).trim());
        Member member = new Member();
        member.setFirstName(first(values, "firstname", "first name", "name"));
        member.setLastName(first(values, "lastname", "last name", "surname"));
        member.setFullName(first(values, "fullname", "full name", "member name", "name"));
        if ((member.getFullName() == null || member.getFullName().isBlank()) && member.getFirstName() != null) {
            member.setFullName((member.getFirstName() + " " + Optional.ofNullable(member.getLastName()).orElse("")).trim());
        }
        member.setFatherOrHusbandName(first(values, "fatherorhusbandname", "father/husband name", "father name", "husband name", "fh name"));
        member.setRelationType(first(values, "relationtype", "relation"));
        member.setSex(first(values, "sex", "gender"));
        member.setAge(parseInt(first(values, "age")));
        member.setAddress(first(values, "address", "addr"));
        var parsedAddress = AddressParser.parse(member.getAddress());
        member.setHouseNo(firstNonBlank(first(values, "houseno", "house no"), parsedAddress.houseNo()));
        member.setArea(firstNonBlank(first(values, "area"), parsedAddress.area()));
        var parsedMobile = MobileNumberParser.parse(first(values, "mobileno", "mobile no", "mobile", "phone"));
        member.setMobileNo(parsedMobile.mobileNo());
        member.setAlternateMobileNo(parsedMobile.alternateMobileNo());
        member.setCasteCategory(firstNonBlank(first(values, "castecategory", "caste category", "caste"), "SC"));
        member.setActive(true);
        member.setSourceType(SourceType.EXCEL_UPLOAD);
        return member;
    }

    private String normalize(String value) {
        return value == null ? "" : value.toLowerCase(Locale.ROOT).replace("_", "").trim();
    }

    private String first(Map<String, String> values, String... keys) {
        for (String key : keys) {
            String value = values.get(normalize(key));
            if (value != null && !value.isBlank()) return value.trim();
        }
        return "";
    }

    private String firstNonBlank(String one, String two) {
        return one != null && !one.isBlank() ? one : (two == null ? "" : two);
    }

    private Integer parseInt(String value) {
        try {
            return value == null || value.isBlank() ? null : (int) Double.parseDouble(value);
        } catch (NumberFormatException ex) {
            return null;
        }
    }
}
