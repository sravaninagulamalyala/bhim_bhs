package com.jystech.bhs.controller;

import com.jystech.bhs.dto.ApiResponse;
import com.jystech.bhs.dto.MemberDtos;
import com.jystech.bhs.entity.Family;
import com.jystech.bhs.entity.Member;
import com.jystech.bhs.repository.FamilyRepository;
import com.jystech.bhs.repository.MemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Comparator;
import java.util.List;
import java.util.Locale;

@RestController
@RequestMapping("/families")
@RequiredArgsConstructor
public class FamilyController {
    private final FamilyRepository familyRepository;
    private final MemberRepository memberRepository;

    @GetMapping("/search")
    public ApiResponse<List<MemberDtos.FamilySearchResponse>> search(@RequestParam(defaultValue = "") String keyword) {
        String value = keyword == null ? "" : keyword.toLowerCase(Locale.ROOT).trim();
        List<MemberDtos.FamilySearchResponse> result = familyRepository.findByActiveTrue().stream()
                .filter(family -> matches(family, value))
                .map(this::toResponse)
                .toList();
        return ApiResponse.ok(result);
    }

    private MemberDtos.FamilySearchResponse toResponse(Family family) {
        List<Member> members = memberRepository.findByFamilyIdAndActiveTrue(family.getId());
        Member head = familyHead(family, members);
        return new MemberDtos.FamilySearchResponse(
                family.getId(),
                family.getFamilyCode(),
                head == null ? "" : head.getFullName(),
                family.getHouseNo(),
                family.getArea(),
                members.size(),
                members.stream().map(Member::getFullName).filter(name -> name != null && !name.isBlank()).toList());
    }

    private boolean matches(Family family, String keyword) {
        if (keyword.isBlank()) return true;
        List<Member> members = memberRepository.findByFamilyIdAndActiveTrue(family.getId());
        Member head = familyHead(family, members);
        return contains(family.getFamilyCode(), keyword)
                || contains(family.getHouseNo(), keyword)
                || contains(family.getArea(), keyword)
                || (head != null && contains(head.getFullName(), keyword))
                || members.stream().anyMatch(member -> contains(member.getFullName(), keyword) || contains(member.getMobileNo(), keyword) || contains(member.getAlternateMobileNo(), keyword));
    }

    private boolean contains(String value, String keyword) {
        return value != null && value.toLowerCase(Locale.ROOT).contains(keyword);
    }

    private Member familyHead(Family family, List<Member> members) {
        if (family.getPrimaryMemberId() != null) {
            for (Member member : members) {
                if (family.getPrimaryMemberId().equals(member.getId())) return member;
            }
        }
        return members.stream().filter(member -> member.getAge() != null).max(Comparator.comparing(Member::getAge))
                .orElseGet(() -> members.stream().min(Comparator.comparing(Member::getId, Comparator.nullsLast(Long::compareTo))).orElse(null));
    }
}
