package com.jystech.bhs.service;

import com.jystech.bhs.dto.MemberDtos;
import com.jystech.bhs.entity.Staff;

import java.util.List;

public interface StaffService {
    Staff create(MemberDtos.StaffCreateRequest request);
    List<Staff> all();
    Staff update(Long id, MemberDtos.StaffUpdateRequest request);
}
