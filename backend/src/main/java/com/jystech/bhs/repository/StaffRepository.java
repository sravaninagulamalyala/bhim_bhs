package com.jystech.bhs.repository;

import com.jystech.bhs.entity.Staff;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface StaffRepository extends JpaRepository<Staff, Long> {
    Optional<Staff> findByAdminId(String adminId);
    boolean existsByAdminId(String adminId);
}
