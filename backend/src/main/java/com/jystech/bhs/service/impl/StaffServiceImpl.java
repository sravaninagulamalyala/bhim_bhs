package com.jystech.bhs.service.impl;

import com.jystech.bhs.audit.AuditService;
import com.jystech.bhs.dto.MemberDtos;
import com.jystech.bhs.entity.Member;
import com.jystech.bhs.entity.Staff;
import com.jystech.bhs.exception.BadRequestException;
import com.jystech.bhs.exception.ResourceNotFoundException;
import com.jystech.bhs.repository.MemberRepository;
import com.jystech.bhs.repository.StaffRepository;
import com.jystech.bhs.service.StaffService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class StaffServiceImpl implements StaffService {
    private final StaffRepository staffRepository;
    private final MemberRepository memberRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuditService auditService;

    @Override
    public Staff create(MemberDtos.StaffCreateRequest request) {
        if (request.adminId() == null || request.adminId().isBlank()) {
            throw new BadRequestException("Admin id is required");
        }
        if (request.password() == null || request.password().isBlank()) {
            throw new BadRequestException("Password is required");
        }
        if (request.role() == null) {
            throw new BadRequestException("Role is required");
        }
        if (staffRepository.existsByAdminId(request.adminId())) {
            throw new BadRequestException("Admin id already exists");
        }
        Staff staff = new Staff();
        staff.setAdminId(request.adminId().trim());
        staff.setPassword(passwordEncoder.encode(request.password()));
        staff.setRole(request.role());
        staff.setActive(request.active());
        staff.setMemberId(request.memberId());
        if (request.memberId() != null) {
            Member member = memberRepository.findById(request.memberId())
                    .orElseThrow(() -> new ResourceNotFoundException("Member not found"));
            staff.setFullName(member.getFullName());
            staff.setMobileNo(member.getMobileNo());
        }
        Staff saved = staffRepository.save(staff);
        auditService.log("CREATE", "STAFF", "Created staff: " + saved.getAdminId());
        return saved;
    }

    @Override
    public List<Staff> all() {
        return staffRepository.findAll();
    }

    @Override
    public Staff update(Long id, MemberDtos.StaffUpdateRequest request) {
        Staff staff = staffRepository.findById(id).orElseThrow(() -> new ResourceNotFoundException("Staff not found"));
        if (request.password() != null && !request.password().isBlank()) staff.setPassword(passwordEncoder.encode(request.password()));
        if (request.role() != null) staff.setRole(request.role());
        if (request.active() != null) staff.setActive(request.active());
        if (request.memberId() != null) staff.setMemberId(request.memberId());
        if (request.fullName() != null) staff.setFullName(request.fullName());
        if (request.mobileNo() != null) staff.setMobileNo(request.mobileNo());
        Staff saved = staffRepository.save(staff);
        auditService.log("UPDATE", "STAFF", "Updated staff: " + saved.getAdminId());
        return saved;
    }
}
