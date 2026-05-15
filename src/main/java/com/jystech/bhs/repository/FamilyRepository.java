package com.jystech.bhs.repository;

import com.jystech.bhs.entity.Family;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface FamilyRepository extends JpaRepository<Family, Long> {
    long countByActiveTrue();
    Optional<Family> findFirstByHouseNoAndActiveTrue(String houseNo);
    List<Family> findByActiveTrue();
}
