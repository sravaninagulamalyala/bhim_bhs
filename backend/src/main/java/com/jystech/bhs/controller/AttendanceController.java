package com.jystech.bhs.controller;

import com.jystech.bhs.dto.ApiResponse;
import com.jystech.bhs.dto.AttendanceDtos;
import com.jystech.bhs.entity.Attendance;
import com.jystech.bhs.entity.Meeting;
import com.jystech.bhs.service.AttendanceService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/attendance")
@RequiredArgsConstructor
public class AttendanceController {
    private final AttendanceService attendanceService;

    @PostMapping("/meeting")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN','GENERAL_SECRETARY','JOINT_SECRETARY','ORG_SECRETARY','SECRETARY')")
    public ApiResponse<Meeting> meeting(@RequestBody AttendanceDtos.MeetingRequest request) {
        return ApiResponse.message("Meeting created", attendanceService.createMeeting(request));
    }

    @PostMapping("/mark")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN','GENERAL_SECRETARY','JOINT_SECRETARY','ORG_SECRETARY','SECRETARY')")
    public ApiResponse<List<Attendance>> mark(@RequestBody AttendanceDtos.MarkAttendanceRequest request) {
        return ApiResponse.message("Attendance saved", attendanceService.mark(request));
    }

    @PutMapping("/{attendanceId}")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN','GENERAL_SECRETARY','JOINT_SECRETARY','ORG_SECRETARY','SECRETARY')")
    public ApiResponse<Attendance> update(@PathVariable Long attendanceId, @RequestBody AttendanceDtos.UpdateAttendanceRequest request) {
        return ApiResponse.message("Attendance updated", attendanceService.update(attendanceId, request));
    }

    @DeleteMapping("/{attendanceId}")
    @PreAuthorize("hasAnyRole('SUPER_ADMIN','GENERAL_SECRETARY','JOINT_SECRETARY','ORG_SECRETARY','SECRETARY')")
    public ApiResponse<Void> delete(@PathVariable Long attendanceId) {
        attendanceService.delete(attendanceId);
        return ApiResponse.message("Attendance deleted", null);
    }

    @GetMapping("/meeting-by-date")
    public ApiResponse<AttendanceDtos.MeetingResponse> meetingByDate(@RequestParam LocalDate date) {
        AttendanceDtos.MeetingResponse meeting = attendanceService.meetingByDate(date);
        return meeting == null
                ? ApiResponse.message("No meeting found for selected date", null)
                : ApiResponse.ok(meeting);
    }

    @GetMapping("/meeting-dates")
    public ApiResponse<List<AttendanceDtos.MeetingDateSummary>> meetingDates(@RequestParam String month) {
        return ApiResponse.ok(attendanceService.meetingDates(month));
    }

    @GetMapping("/by-meeting/{meetingId}")
    public ApiResponse<List<Attendance>> byMeeting(@PathVariable Long meetingId) {
        return ApiResponse.ok(attendanceService.byMeeting(meetingId));
    }

    @GetMapping("/by-date")
    public ApiResponse<AttendanceDtos.AttendanceByDateResponse> byDate(@RequestParam LocalDate date) {
        return ApiResponse.ok(attendanceService.byDate(date));
    }
}
