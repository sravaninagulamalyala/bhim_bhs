package com.jystech.bhs.dto;

import com.jystech.bhs.entity.UserRole;

import java.util.List;

public class MemberDtos {
    public record HomeContentResponse(String associationTitle, String registrationNo, String address, String ambedkarImage,
                                      String ambedkarIntroduction, String copyright) {}
    public record CountsResponse(long activeFamilyCount, long activeMemberCount) {}
    public record MemberRegistrationRequest(MemberInput mainMember, List<MemberInput> familyMembers, Long familyId) {}
    public record MemberInput(String firstName, String lastName, String fatherOrHusbandName, Integer age, String sex,
                              String mobileNo, String address) {}
    public record StaffCreateRequest(Long memberId, String adminId, String password, UserRole role, boolean active) {}
    public record StaffUpdateRequest(String password, UserRole role, Boolean active, Long memberId, String fullName, String mobileNo) {}
    public record MemberUpdateRequest(String firstName, String lastName, String fatherOrHusbandName, String relationType,
                                      Integer age, String sex, String mobileNo, String alternateMobileNo, String address,
                                      String houseNo, String area, Boolean active) {}
    public record MapFamilyRequest(Long memberId, Long familyId) {}
    public record MemberFamilyResponse(Object member, List<?> familyMembers) {}
}
