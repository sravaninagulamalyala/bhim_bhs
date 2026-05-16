package com.jystech.bhs.controller;

import com.jystech.bhs.dto.ApiResponse;
import com.jystech.bhs.dto.MemberDtos;
import com.jystech.bhs.repository.FamilyRepository;
import com.jystech.bhs.repository.MemberRepository;
import com.jystech.bhs.service.MemberService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/public")
@RequiredArgsConstructor
public class PublicController {
    private final FamilyRepository familyRepository;
    private final MemberRepository memberRepository;
    private final MemberService memberService;

    @GetMapping("/home-content")
    public ApiResponse<MemberDtos.HomeContentResponse> homeContent() {
        return ApiResponse.ok(new MemberDtos.HomeContentResponse(
                "BHARATHIYA HARIJANA SANGAM",
                "Reg 46/2614",
                "H.No: 7-6-110, Gowtham Nagar, Bowenpally, Hyderabad - 500011",
                "ambedkar.jpg",
                "Bhimrao Ramji Ambedkar was an Indian jurist, economist, social reformer and politician who chaired the committee that drafted the Constitution of India based on the debates of the Constituent Assembly of India.",
                "MJYS Nexora Pvt Ltd"
        ));
    }

    @GetMapping("/counts")
    public ApiResponse<MemberDtos.CountsResponse> counts() {
        return ApiResponse.ok(new MemberDtos.CountsResponse(familyRepository.countByActiveTrue(), memberRepository.countByActiveTrue()));
    }

    @PostMapping("/member-registration")
    public ApiResponse<Object> register(@RequestBody MemberDtos.MemberRegistrationRequest request) {
        return ApiResponse.message("Member registration submitted", memberService.register(request));
    }
}
