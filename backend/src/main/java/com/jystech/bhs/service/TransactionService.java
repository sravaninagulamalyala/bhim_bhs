package com.jystech.bhs.service;

import com.jystech.bhs.dto.TransactionDtos;
import com.jystech.bhs.entity.TransactionRecord;

import java.io.ByteArrayInputStream;
import java.time.YearMonth;
import java.util.List;
import java.util.Map;

public interface TransactionService {
    TransactionRecord create(TransactionDtos.TransactionRequest request);
    List<TransactionRecord> all();
    TransactionDtos.BalanceResponse balance();
    Map<String, Object> monthlySummary(YearMonth month);
    TransactionDtos.MonthlyStatementResponse monthlyStatement(YearMonth month);
    ByteArrayInputStream downloadStatement(YearMonth month);
}
