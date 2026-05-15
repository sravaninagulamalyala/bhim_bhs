package com.jystech.bhs.mapper;

import com.jystech.bhs.dto.MemberDtos;
import com.jystech.bhs.entity.Member;
import com.jystech.bhs.entity.SourceType;
import com.jystech.bhs.util.AddressParser;
import com.jystech.bhs.util.MobileNumberParser;

public final class MemberMapper {
    private MemberMapper() {
    }

    public static Member fromRegistration(MemberDtos.MemberInput input) {
        Member member = new Member();
        member.setFirstName(AddressParser.clean(input.firstName()));
        member.setLastName(AddressParser.clean(input.lastName()));
        member.setFullName((member.getFirstName() + " " + member.getLastName()).trim());
        member.setFatherOrHusbandName(AddressParser.clean(input.fatherOrHusbandName()));
        member.setAge(input.age());
        member.setSex(input.sex());
        member.setAddress(AddressParser.clean(input.address()));
        var parsedAddress = AddressParser.parse(input.address());
        member.setHouseNo(parsedAddress.houseNo());
        member.setArea(parsedAddress.area());
        var parsedMobile = MobileNumberParser.parse(input.mobileNo());
        member.setMobileNo(parsedMobile.mobileNo());
        member.setAlternateMobileNo(parsedMobile.alternateMobileNo());
        member.setActive(true);
        member.setSourceType(SourceType.MEMBER_REGISTRATION);
        return member;
    }
}
