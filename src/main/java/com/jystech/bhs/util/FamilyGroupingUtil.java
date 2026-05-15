package com.jystech.bhs.util;

import com.jystech.bhs.entity.Family;
import com.jystech.bhs.entity.Member;
import com.jystech.bhs.repository.FamilyRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class FamilyGroupingUtil {
    private final FamilyRepository familyRepository;

    public Family resolveFamily(Member member) {
        if (member.getHouseNo() != null && !member.getHouseNo().isBlank()) {
            return familyRepository.findFirstByHouseNoAndActiveTrue(member.getHouseNo())
                    .orElseGet(() -> createFamily(member));
        }
        return createFamily(member);
    }

    private Family createFamily(Member member) {
        Family family = new Family();
        family.setFamilyCode(nextCode());
        family.setHouseNo(member.getHouseNo());
        family.setArea(member.getArea());
        family.setAddress(member.getAddress());
        family.setActive(true);
        return familyRepository.save(family);
    }

    private String nextCode() {
        return "BHS-FAM-" + System.currentTimeMillis();
    }
}
