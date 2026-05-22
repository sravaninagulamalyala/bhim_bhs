package com.jystech.bhs.controller;

import com.jystech.bhs.dto.ApiResponse;
import com.jystech.bhs.dto.MemberDtos;
import com.jystech.bhs.entity.Member;
import com.jystech.bhs.repository.FamilyRepository;
import com.jystech.bhs.service.MemberService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/search")
@RequiredArgsConstructor
public class SearchController {
    private final MemberService memberService;
    private final FamilyRepository familyRepository;

    @GetMapping("/member-family")
    public ApiResponse<List<MemberDtos.MemberFamilyResponse>> memberFamily(@RequestParam(defaultValue = "") String keyword) {
        List<MemberDtos.MemberFamilyResponse> result = memberService.search(keyword).stream()
                .map(member -> new MemberDtos.MemberFamilyResponse(member, member.getFamilyId() == null ? List.of() : memberService.family(member.getId())))
                .toList();
        return ApiResponse.ok(result);
    }

    @GetMapping("/members")
    public ApiResponse<List<Map<String, Object>>> members(@RequestParam(defaultValue = "") String keyword) {
        return ApiResponse.ok(memberService.search(keyword).stream().map(this::memberSummary).toList());
    }

    private Map<String, Object> memberSummary(Member member) {
        Map<String, Object> row = new LinkedHashMap<>();
        row.put("id", member.getId());
        row.put("familyId", member.getFamilyId());
        row.put("familyCode", member.getFamilyId() == null ? null : familyRepository.findById(member.getFamilyId()).map(f -> f.getFamilyCode()).orElse(null));
        row.put("fullName", member.getFullName());
        row.put("fatherOrHusbandName", member.getFatherOrHusbandName());
        row.put("mobileNo", member.getMobileNo());
        row.put("houseNo", member.getHouseNo());
        row.put("area", member.getArea());
        return row;
    }
}
