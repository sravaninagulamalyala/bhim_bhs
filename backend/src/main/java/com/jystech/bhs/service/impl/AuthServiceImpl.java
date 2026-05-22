package com.jystech.bhs.service.impl;

import com.jystech.bhs.audit.AuditService;
import com.jystech.bhs.dto.AuthDtos;
import com.jystech.bhs.entity.Staff;
import com.jystech.bhs.exception.BadRequestException;
import com.jystech.bhs.repository.StaffRepository;
import com.jystech.bhs.security.JwtUtil;
import com.jystech.bhs.service.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthServiceImpl implements AuthService {
    private final StaffRepository staffRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;
    private final AuditService auditService;

    @Override
    public AuthDtos.LoginResponse login(AuthDtos.LoginRequest request) {
        Staff staff = staffRepository.findByAdminId(request.adminId())
                .filter(Staff::isActive)
                .orElseThrow(() -> new BadRequestException("Invalid credentials"));
        if (!passwordEncoder.matches(request.password(), staff.getPassword())) {
            throw new BadRequestException("Invalid credentials");
        }
        auditService.log("LOGIN", "AUTH", "Staff login: " + staff.getAdminId());
        return new AuthDtos.LoginResponse(jwtUtil.generateToken(staff), staff.getRole(), AuthDtos.StaffDetails.from(staff));
    }

    @Override
    public AuthDtos.CaptchaResponse captcha() {
        return new AuthDtos.CaptchaResponse("", "");
    }
}
