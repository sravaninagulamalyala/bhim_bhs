package com.jystech.bhs.controller;

import com.jystech.bhs.dto.ApiResponse;
import com.jystech.bhs.service.ReportService;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.InputStreamResource;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.YearMonth;
import java.util.Map;

@RestController
@RequestMapping("/reports")
@RequiredArgsConstructor
public class ReportController {
    private final ReportService reportService;

    @GetMapping("/family-member-count")
    public ApiResponse<Map<String, Object>> familyMemberCount() {
        return ApiResponse.ok(reportService.familyMemberCount());
    }

    @GetMapping("/monthly-contribution")
    public ApiResponse<Map<String, Object>> monthlyContribution(@RequestParam @DateTimeFormat(pattern = "yyyy-MM") YearMonth month) {
        return ApiResponse.ok(reportService.monthlyContribution(month));
    }

    @GetMapping("/contributed-families")
    public ApiResponse<Map<String, Object>> contributedFamilies(@RequestParam @DateTimeFormat(pattern = "yyyy-MM") YearMonth month) {
        return ApiResponse.ok(reportService.contributedFamilies(month));
    }

    @GetMapping("/non-contributed-families")
    public ApiResponse<Map<String, Object>> nonContributedFamilies(@RequestParam @DateTimeFormat(pattern = "yyyy-MM") YearMonth month) {
        return ApiResponse.ok(reportService.nonContributedFamilies(month));
    }

    @GetMapping("/heatmap")
    public ApiResponse<Map<String, Object>> heatmap(@RequestParam @DateTimeFormat(pattern = "yyyy-MM") YearMonth month) {
        return ApiResponse.ok(reportService.heatmap(month));
    }

    @GetMapping("/download")
    public ResponseEntity<InputStreamResource> download(@RequestParam String type, @RequestParam @DateTimeFormat(pattern = "yyyy-MM") YearMonth month) {
        String filename = "bhs-" + type.toLowerCase() + "-" + month + ".xlsx";
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=" + filename)
                .contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                .body(new InputStreamResource(reportService.download(type, month)));
    }
}
