package com.jystech.bhs.controller;

import com.jystech.bhs.dto.ApiResponse;
import com.jystech.bhs.dto.AttendanceDtos;
import com.jystech.bhs.entity.Attendance;
import com.jystech.bhs.entity.Meeting;
import com.jystech.bhs.service.AttendanceService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/attendance")
@RequiredArgsConstructor
public class AttendanceController {
    private final AttendanceService attendanceService;

    @PostMapping("/meeting")
    public ApiResponse<Meeting> meeting(@RequestBody AttendanceDtos.MeetingRequest request) {
        return ApiResponse.message("Meeting created", attendanceService.createMeeting(request));
    }

    @PostMapping("/mark")
    public ApiResponse<List<Attendance>> mark(@RequestBody AttendanceDtos.MarkAttendanceRequest request) {
        return ApiResponse.message("Attendance saved", attendanceService.mark(request));
    }

    @GetMapping("/by-meeting/{meetingId}")
    public ApiResponse<List<Attendance>> byMeeting(@PathVariable Long meetingId) {
        return ApiResponse.ok(attendanceService.byMeeting(meetingId));
    }

    @GetMapping("/by-date")
    public ApiResponse<List<Attendance>> byDate(@RequestParam LocalDate date) {
        return ApiResponse.ok(attendanceService.byDate(date));
    }
}
