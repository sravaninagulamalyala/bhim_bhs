package com.jystech.bhs.dto;

import com.jystech.bhs.entity.TransactionType;

import java.math.BigDecimal;
import java.time.LocalDate;

public class TransactionDtos {
    public record TransactionRequest(LocalDate transactionDate, Long familyId, Long memberId, TransactionType transactionType,
                                     BigDecimal amount, String remarks) {}
    public record BalanceResponse(BigDecimal totalCredit, BigDecimal totalDebit, BigDecimal balance) {}
}
