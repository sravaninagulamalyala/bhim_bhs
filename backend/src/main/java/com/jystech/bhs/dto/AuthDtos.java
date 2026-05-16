package com.jystech.bhs.dto;

import com.jystech.bhs.entity.Staff;
import com.jystech.bhs.entity.UserRole;

public class AuthDtos {
    public record LoginRequest(String adminId, String password, String captcha, String captchaKey) {}
    public record LoginResponse(String token, UserRole role, StaffDetails staff) {}
    public record CaptchaResponse(String key, String text) {}
    public record StaffDetails(Long id, String adminId, UserRole role, Long memberId, String fullName, String mobileNo) {
        public static StaffDetails from(Staff staff) {
            return new StaffDetails(staff.getId(), staff.getAdminId(), staff.getRole(), staff.getMemberId(), staff.getFullName(), staff.getMobileNo());
        }
    }
}
