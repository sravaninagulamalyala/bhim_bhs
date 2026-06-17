package com.jystech.bhs.service;

import com.jystech.bhs.dto.AttendanceDtos;
import com.jystech.bhs.entity.Attendance;
import com.jystech.bhs.entity.Meeting;

import java.time.LocalDate;
import java.util.List;

public interface AttendanceService {
    Meeting createMeeting(AttendanceDtos.MeetingRequest request);
    List<Attendance> mark(AttendanceDtos.MarkAttendanceRequest request);
    List<Attendance> byMeeting(Long meetingId);
    AttendanceDtos.MeetingResponse meetingByDate(LocalDate date);
    List<AttendanceDtos.MeetingDateSummary> meetingDates(String month);
    AttendanceDtos.AttendanceByDateResponse byDate(LocalDate date);
    Attendance update(Long attendanceId, AttendanceDtos.UpdateAttendanceRequest request);
    void delete(Long attendanceId);
}
