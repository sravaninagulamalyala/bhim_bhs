package com.jystech.bhs.service.impl;

import com.jystech.bhs.audit.AuditService;
import com.jystech.bhs.dto.AttendanceDtos;
import com.jystech.bhs.entity.Attendance;
import com.jystech.bhs.entity.Meeting;
import com.jystech.bhs.entity.Member;
import com.jystech.bhs.exception.ResourceNotFoundException;
import com.jystech.bhs.repository.AttendanceRepository;
import com.jystech.bhs.repository.MeetingRepository;
import com.jystech.bhs.repository.MemberRepository;
import com.jystech.bhs.service.AttendanceService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
public class AttendanceServiceImpl implements AttendanceService {
    private final MeetingRepository meetingRepository;
    private final AttendanceRepository attendanceRepository;
    private final MemberRepository memberRepository;
    private final AuditService auditService;

    @Override
    public Meeting createMeeting(AttendanceDtos.MeetingRequest request) {
        Meeting meeting = new Meeting();
        meeting.setMeetingDate(request.meetingDate());
        meeting.setTitle(request.title());
        meeting.setRemarks(request.remarks());
        meeting.setCreatedBy(currentUser());
        Meeting saved = meetingRepository.save(meeting);
        auditService.log("CREATE", "ATTENDANCE", "Created meeting id: " + saved.getId());
        return saved;
    }

    @Override
    public List<Attendance> mark(AttendanceDtos.MarkAttendanceRequest request) {
        meetingRepository.findById(request.meetingId()).orElseThrow(() -> new ResourceNotFoundException("Meeting not found"));
        List<Attendance> saved = new ArrayList<>();
        for (AttendanceDtos.AttendanceItem item : request.attendance()) {
            Member member = memberRepository.findById(item.memberId()).orElseThrow(() -> new ResourceNotFoundException("Member not found"));
            Attendance attendance = attendanceRepository.findByMeetingIdAndMemberId(request.meetingId(), item.memberId()).orElseGet(Attendance::new);
            attendance.setMeetingId(request.meetingId());
            attendance.setMemberId(member.getId());
            attendance.setFamilyId(member.getFamilyId());
            attendance.setAttended(Boolean.TRUE.equals(item.attended()));
            attendance.setMarkedBy(currentUser());
            attendance.setMarkedAt(LocalDateTime.now());
            saved.add(attendanceRepository.save(attendance));
        }
        auditService.log("UPSERT", "ATTENDANCE", "Marked attendance for meeting id: " + request.meetingId());
        return saved;
    }

    @Override
    public List<Attendance> byMeeting(Long meetingId) {
        return attendanceRepository.findByMeetingId(meetingId);
    }

    @Override
    public List<Attendance> byDate(LocalDate date) {
        List<Attendance> rows = new ArrayList<>();
        meetingRepository.findByMeetingDate(date).forEach(meeting -> rows.addAll(attendanceRepository.findByMeetingId(meeting.getId())));
        return rows;
    }

    private String currentUser() {
        return SecurityContextHolder.getContext().getAuthentication().getName();
    }
}
