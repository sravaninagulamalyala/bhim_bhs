package com.jystech.bhs.dto;

import com.jystech.bhs.entity.TransactionType;

import java.math.BigDecimal;
import java.time.LocalDate;

public class TransactionDtos {
    public record TransactionRequest(LocalDate transactionDate, Long familyId, Long memberId, TransactionType transactionType,
                                     BigDecimal amount, String purpose, String remarks) {}
    public record BalanceResponse(BigDecimal totalCredit, BigDecimal totalDebit, BigDecimal balance) {}
    public record StatementTransaction(Long transactionId, LocalDate transactionDate, TransactionType transactionType,
                                       String purpose, String remarks, BigDecimal creditAmount, BigDecimal debitAmount,
                                       BigDecimal balanceAfterTransaction, String createdBy) {}
    public record MonthlyStatementResponse(String month, BigDecimal openingBalance, BigDecimal totalCredit, BigDecimal totalDebit,
                                           BigDecimal closingBalance, BigDecimal creditPercentage, BigDecimal debitPercentage,
                                           java.util.List<StatementTransaction> transactions) {}
}
