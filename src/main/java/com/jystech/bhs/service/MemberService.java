package com.jystech.bhs.service;

import com.jystech.bhs.dto.MemberDtos;
import com.jystech.bhs.entity.Member;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

public interface MemberService {
    Object register(MemberDtos.MemberRegistrationRequest request);
    List<Member> search(String keyword);
    Member update(Long id, MemberDtos.MemberUpdateRequest request);
    List<Member> family(Long memberId);
    Member mapFamily(MemberDtos.MapFamilyRequest request);
    int uploadExcel(MultipartFile file);
}
