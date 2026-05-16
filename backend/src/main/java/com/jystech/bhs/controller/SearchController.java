package com.jystech.bhs.controller;

import com.jystech.bhs.dto.ApiResponse;
import com.jystech.bhs.dto.MemberDtos;
import com.jystech.bhs.entity.Member;
import com.jystech.bhs.service.MemberService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/search")
@RequiredArgsConstructor
public class SearchController {
    private final MemberService memberService;

    @GetMapping("/member-family")
    public ApiResponse<List<MemberDtos.MemberFamilyResponse>> memberFamily(@RequestParam(defaultValue = "") String keyword) {
        List<MemberDtos.MemberFamilyResponse> result = memberService.search(keyword).stream()
                .map(member -> new MemberDtos.MemberFamilyResponse(member, member.getFamilyId() == null ? List.of() : memberService.family(member.getId())))
                .toList();
        return ApiResponse.ok(result);
    }
}
