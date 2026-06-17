package com.jystech.bhs.dto;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

public class AttendanceDtos {
    public record MeetingRequest(LocalDate meetingDate, String title, String remarks) {}
    public record AttendanceItem(Long memberId, Boolean attended) {}
    public record UpdateAttendanceRequest(Boolean attended) {}
    public record MarkAttendanceRequest(Long meetingId, List<AttendanceItem> attendanceList, List<AttendanceItem> attendance) {
        public List<AttendanceItem> items() {
            return attendanceList != null ? attendanceList : attendance;
        }
    }
    public record MeetingResponse(Long meetingId, LocalDate meetingDate, String title, String remarks) {}
    public record MeetingDateSummary(Long meetingId, LocalDate meetingDate, long presentCount, long totalMarkedCount) {}
    public record AttendanceByDateResponse(MeetingResponse meeting, List<Map<String, Object>> presentMembers, List<Map<String, Object>> absentMembers) {}
}
