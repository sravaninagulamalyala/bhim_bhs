package com.jystech.bhs.repository;

import com.jystech.bhs.entity.Member;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface MemberRepository extends JpaRepository<Member, Long> {
    long countByActiveTrue();
    List<Member> findByFamilyIdAndActiveTrue(Long familyId);
    List<Member> findByHouseNoAndActiveTrue(String houseNo);

    @Query("""
            select m from Member m
            where m.active = true and (
              lower(coalesce(m.fullName, '')) like lower(concat('%', :keyword, '%'))
              or lower(coalesce(m.firstName, '')) like lower(concat('%', :keyword, '%'))
              or lower(coalesce(m.fatherOrHusbandName, '')) like lower(concat('%', :keyword, '%'))
              or lower(coalesce(m.mobileNo, '')) like lower(concat('%', :keyword, '%'))
              or lower(coalesce(m.houseNo, '')) like lower(concat('%', :keyword, '%'))
              or lower(coalesce(m.address, '')) like lower(concat('%', :keyword, '%'))
              or exists (
                select f.id from Family f
                where f.id = m.familyId
                  and lower(coalesce(f.familyCode, '')) like lower(concat('%', :keyword, '%'))
              )
            )
            order by m.fullName
            """)
    List<Member> search(@Param("keyword") String keyword);
}
