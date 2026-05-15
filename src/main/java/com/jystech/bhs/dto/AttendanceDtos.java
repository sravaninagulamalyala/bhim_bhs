package com.jystech.bhs.dto;

import java.time.LocalDate;
import java.util.List;

public class AttendanceDtos {
    public record MeetingRequest(LocalDate meetingDate, String title, String remarks) {}
    public record AttendanceItem(Long memberId, Boolean attended) {}
    public record MarkAttendanceRequest(Long meetingId, List<AttendanceItem> attendance) {}
}
