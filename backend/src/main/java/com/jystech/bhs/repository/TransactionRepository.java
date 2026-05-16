package com.jystech.bhs.repository;

import com.jystech.bhs.entity.TransactionRecord;
import com.jystech.bhs.entity.TransactionType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public interface TransactionRepository extends JpaRepository<TransactionRecord, Long> {
    List<TransactionRecord> findByTransactionDateBetweenOrderByTransactionDateDesc(LocalDate start, LocalDate end);
    List<TransactionRecord> findAllByOrderByTransactionDateDesc();

    @Query("select coalesce(sum(t.amount), 0) from TransactionRecord t where t.transactionType = :type")
    BigDecimal sumByType(@Param("type") TransactionType type);

    @Query("""
            select distinct t.familyId from TransactionRecord t
            where t.transactionType = com.jystech.bhs.entity.TransactionType.CREDIT
              and t.familyId is not null
              and t.transactionDate between :start and :end
            """)
    List<Long> contributedFamilyIds(@Param("start") LocalDate start, @Param("end") LocalDate end);
}
