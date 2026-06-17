package com.jystech.bhs.controller;

import com.jystech.bhs.dto.ApiResponse;
import com.jystech.bhs.dto.TransactionDtos;
import com.jystech.bhs.entity.TransactionRecord;
import com.jystech.bhs.service.TransactionService;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.InputStreamResource;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.YearMonth;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/transactions")
@RequiredArgsConstructor
public class TransactionController {
    private final TransactionService transactionService;

    @PostMapping
    @PreAuthorize("hasAnyRole('TREASURER','SUPER_ADMIN')")
    public ApiResponse<TransactionRecord> create(@RequestBody TransactionDtos.TransactionRequest request) {
        return ApiResponse.message("Transaction saved", transactionService.create(request));
    }

    @GetMapping
    public ApiResponse<List<TransactionRecord>> all() {
        return ApiResponse.ok(transactionService.all());
    }

    @GetMapping("/balance")
    public ApiResponse<TransactionDtos.BalanceResponse> balance() {
        return ApiResponse.ok(transactionService.balance());
    }

    @GetMapping("/monthly-summary")
    public ApiResponse<Map<String, Object>> monthlySummary(@RequestParam @DateTimeFormat(pattern = "yyyy-MM") YearMonth month) {
        return ApiResponse.ok(transactionService.monthlySummary(month));
    }

    @GetMapping("/monthly-statement")
    public ApiResponse<TransactionDtos.MonthlyStatementResponse> monthlyStatement(@RequestParam @DateTimeFormat(pattern = "yyyy-MM") YearMonth month) {
        return ApiResponse.ok(transactionService.monthlyStatement(month));
    }

    @GetMapping("/download-statement")
    public ResponseEntity<InputStreamResource> downloadStatement(@RequestParam @DateTimeFormat(pattern = "yyyy-MM") YearMonth month) {
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=bhs-transaction-statement-" + month + ".xlsx")
                .contentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"))
                .body(new InputStreamResource(transactionService.downloadStatement(month)));
    }
}
