package com.jystech.bhs.controller;

import com.jystech.bhs.dto.ApiResponse;
import com.jystech.bhs.entity.AuditLog;
import com.jystech.bhs.dto.MemberDtos;
import com.jystech.bhs.entity.Staff;
import com.jystech.bhs.repository.AuditLogRepository;
import com.jystech.bhs.service.MemberService;
import com.jystech.bhs.service.StaffService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/admin")
@RequiredArgsConstructor
public class AdminController {
    private final MemberService memberService;
    private final StaffService staffService;
    private final AuditLogRepository auditLogRepository;

    @PostMapping("/members/upload-excel")
    public ApiResponse<Map<String, Integer>> uploadExcel(@RequestParam("file") MultipartFile file) {
        return ApiResponse.message("Excel uploaded", Map.of("insertedRecords", memberService.uploadExcel(file)));
    }

    @PostMapping("/staff/create")
    public ApiResponse<Staff> createStaff(@RequestBody MemberDtos.StaffCreateRequest request) {
        return ApiResponse.message("Staff created", staffService.create(request));
    }

    @GetMapping("/staff")
    public ApiResponse<List<Staff>> staff() {
        return ApiResponse.ok(staffService.all());
    }

    @PutMapping("/staff/{id}")
    public ApiResponse<Staff> updateStaff(@PathVariable Long id, @RequestBody MemberDtos.StaffUpdateRequest request) {
        return ApiResponse.message("Staff updated", staffService.update(id, request));
    }

    @GetMapping("/audit-logs")
    public ApiResponse<List<AuditLog>> auditLogs() {
        return ApiResponse.ok(auditLogRepository.findTop100ByOrderByCreatedAtDesc());
    }
}
