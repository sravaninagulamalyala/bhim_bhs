package com.jystech.bhs.controller;

import com.jystech.bhs.dto.ApiResponse;
import com.jystech.bhs.dto.MemberDtos;
import com.jystech.bhs.entity.Member;
import com.jystech.bhs.service.MemberService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/members")
@RequiredArgsConstructor
public class MemberController {
    private final MemberService memberService;

    @GetMapping("/search")
    public ApiResponse<List<Member>> search(@RequestParam(defaultValue = "") String keyword) {
        return ApiResponse.ok(memberService.search(keyword));
    }

    @GetMapping("/{id}/family")
    public ApiResponse<List<Member>> family(@PathVariable Long id) {
        return ApiResponse.ok(memberService.family(id));
    }

    @GetMapping("/{id}/details")
    public ApiResponse<MemberDtos.MemberDetailsResponse> details(@PathVariable Long id) {
        return ApiResponse.ok(memberService.details(id));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('SECRETARY','SUPER_ADMIN')")
    public ApiResponse<Member> update(@PathVariable Long id, @RequestBody MemberDtos.MemberUpdateRequest request) {
        return ApiResponse.message("Member updated", memberService.update(id, request));
    }

    @PostMapping("/map-family")
    @PreAuthorize("hasAnyRole('SECRETARY','SUPER_ADMIN')")
    public ApiResponse<Member> mapFamily(@RequestBody MemberDtos.MapFamilyRequest request) {
        return ApiResponse.message("Family mapped", memberService.mapFamily(request));
    }

    @PostMapping("/family/remove")
    public ApiResponse<Member> removeFromFamily(@RequestBody MemberDtos.RemoveFamilyRequest request) {
        return ApiResponse.message("Member removed from family", memberService.removeFromFamily(request));
    }

    @PostMapping("/family/add")
    public ApiResponse<Member> addToFamily(@RequestBody MemberDtos.AddFamilyRequest request) {
        return ApiResponse.message("Member added to family", memberService.addToFamily(request));
    }
}
