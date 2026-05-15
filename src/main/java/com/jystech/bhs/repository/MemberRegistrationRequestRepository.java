package com.jystech.bhs.repository;

import com.jystech.bhs.entity.MemberRegistrationRequest;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MemberRegistrationRequestRepository extends JpaRepository<MemberRegistrationRequest, Long> {
}
