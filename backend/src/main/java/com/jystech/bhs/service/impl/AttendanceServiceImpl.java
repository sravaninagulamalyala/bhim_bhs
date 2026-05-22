package com.jystech.bhs.service.impl;

import com.jystech.bhs.audit.AuditService;
import com.jystech.bhs.dto.AttendanceDtos;
import com.jystech.bhs.entity.Attendance;
import com.jystech.bhs.entity.Meeting;
import com.jystech.bhs.entity.Member;
import com.jystech.bhs.exception.BadRequestException;
import com.jystech.bhs.exception.ResourceNotFoundException;
import com.jystech.bhs.repository.AttendanceRepository;
import com.jystech.bhs.repository.FamilyRepository;
import com.jystech.bhs.repository.MeetingRepository;
import com.jystech.bhs.repository.MemberRepository;
import com.jystech.bhs.service.AttendanceService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class AttendanceServiceImpl implements AttendanceService {
    private final MeetingRepository meetingRepository;
    private final AttendanceRepository attendanceRepository;
    private final MemberRepository memberRepository;
    private final FamilyRepository familyRepository;
    private final AuditService auditService;

    @Override
    public Meeting createMeeting(AttendanceDtos.MeetingRequest request) {
        if (request.meetingDate() == null) {
            throw new BadRequestException("Meeting date is required");
        }
        if (request.title() == null || request.title().isBlank()) {
            throw new BadRequestException("Meeting title is required");
        }
        Meeting existing = meetingRepository.findFirstByMeetingDate(request.meetingDate()).orElse(null);
        if (existing != null) {
            return existing;
        }
        Meeting meeting = new Meeting();
        meeting.setMeetingDate(request.meetingDate());
        meeting.setTitle(request.title().trim());
        meeting.setRemarks(request.remarks() == null ? null : request.remarks().trim());
        meeting.setCreatedBy(currentUser());
        Meeting saved = meetingRepository.save(meeting);
        auditService.log("CREATE", "ATTENDANCE", "Created meeting id: " + saved.getId());
        return saved;
    }

    @Override
    public List<Attendance> mark(AttendanceDtos.MarkAttendanceRequest request) {
        if (request.meetingId() == null) {
            throw new BadRequestException("Meeting id is required");
        }
        List<AttendanceDtos.AttendanceItem> items = request.items();
        if (items == null || items.isEmpty()) {
            throw new BadRequestException("Attendance list is required");
        }
        meetingRepository.findById(request.meetingId()).orElseThrow(() -> new ResourceNotFoundException("Meeting not found"));
        List<Attendance> saved = new ArrayList<>();
        int created = 0;
        int updated = 0;
        for (AttendanceDtos.AttendanceItem item : items) {
            if (item.memberId() == null) {
                throw new BadRequestException("Member id is required");
            }
            Member member = memberRepository.findById(item.memberId()).orElseThrow(() -> new ResourceNotFoundException("Member not found"));
            Attendance attendance = attendanceRepository.findByMeetingIdAndMemberId(request.meetingId(), item.memberId()).orElse(null);
            boolean isNew = attendance == null;
            if (isNew) attendance = new Attendance();
            attendance.setMeetingId(request.meetingId());
            attendance.setMemberId(member.getId());
            attendance.setFamilyId(member.getFamilyId());
            attendance.setAttended(Boolean.TRUE.equals(item.attended()));
            attendance.setMarkedBy(currentUser());
            attendance.setMarkedAt(LocalDateTime.now());
            saved.add(attendanceRepository.save(attendance));
            if (isNew) created++; else updated++;
        }
        if (created > 0) auditService.log("CREATE", "ATTENDANCE", "Marked attendance for meeting id: " + request.meetingId() + ", rows: " + created);
        if (updated > 0) auditService.log("UPDATE", "ATTENDANCE", "Updated attendance for meeting id: " + request.meetingId() + ", rows: " + updated);
        return saved;
    }

    @Override
    public List<Attendance> byMeeting(Long meetingId) {
        return attendanceRepository.findByMeetingId(meetingId);
    }

    @Override
    public AttendanceDtos.MeetingResponse meetingByDate(LocalDate date) {
        if (date == null) throw new BadRequestException("Meeting date is required");
        return meetingRepository.findFirstByMeetingDate(date).map(this::toMeetingResponse).orElse(null);
    }

    @Override
    public List<AttendanceDtos.MeetingDateSummary> meetingDates(String month) {
        if (month == null || month.isBlank()) throw new BadRequestException("Month is required");
        YearMonth yearMonth;
        try {
            yearMonth = YearMonth.parse(month);
        } catch (Exception ex) {
            throw new BadRequestException("Month must be in yyyy-MM format");
        }
        return meetingRepository.findByMeetingDateBetweenOrderByMeetingDate(yearMonth.atDay(1), yearMonth.atEndOfMonth()).stream()
                .map(meeting -> new AttendanceDtos.MeetingDateSummary(
                        meeting.getId(),
                        meeting.getMeetingDate(),
                        attendanceRepository.countByMeetingIdAndAttendedTrue(meeting.getId()),
                        attendanceRepository.countByMeetingId(meeting.getId())))
                .toList();
    }

    @Override
    public AttendanceDtos.AttendanceByDateResponse byDate(LocalDate date) {
        if (date == null) throw new BadRequestException("Meeting date is required");
        Meeting meeting = meetingRepository.findFirstByMeetingDate(date).orElseThrow(() -> new ResourceNotFoundException("Meeting not found"));
        List<Map<String, Object>> present = new ArrayList<>();
        List<Map<String, Object>> absent = new ArrayList<>();
        for (Attendance attendance : attendanceRepository.findByMeetingId(meeting.getId())) {
            Member member = memberRepository.findById(attendance.getMemberId()).orElse(null);
            Map<String, Object> row = memberRow(member, attendance);
            if (attendance.isAttended()) present.add(row); else absent.add(row);
        }
        return new AttendanceDtos.AttendanceByDateResponse(toMeetingResponse(meeting), present, absent);
    }

    private AttendanceDtos.MeetingResponse toMeetingResponse(Meeting meeting) {
        return new AttendanceDtos.MeetingResponse(meeting.getId(), meeting.getMeetingDate(), meeting.getTitle(), meeting.getRemarks());
    }

    private Map<String, Object> memberRow(Member member, Attendance attendance) {
        Map<String, Object> row = new LinkedHashMap<>();
        row.put("memberId", attendance.getMemberId());
        row.put("fullName", member == null ? "" : member.getFullName());
        row.put("mobileNo", member == null ? "" : member.getMobileNo());
        Long familyId = member == null ? attendance.getFamilyId() : member.getFamilyId();
        row.put("familyCode", familyId == null ? null : familyRepository.findById(familyId).map(f -> f.getFamilyCode()).orElse(null));
        row.put("familyId", familyId);
        row.put("houseNo", member == null ? "" : member.getHouseNo());
        row.put("attended", attendance.isAttended());
        row.put("markedBy", attendance.getMarkedBy());
        row.put("markedAt", attendance.getMarkedAt());
        return row;
    }

    private String currentUser() {
        return SecurityContextHolder.getContext().getAuthentication().getName();
    }
}
