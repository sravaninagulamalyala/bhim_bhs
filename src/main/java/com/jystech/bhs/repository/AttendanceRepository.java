package com.jystech.bhs.repository;

import com.jystech.bhs.entity.Attendance;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface AttendanceRepository extends JpaRepository<Attendance, Long> {
    List<Attendance> findByMeetingId(Long meetingId);
    Optional<Attendance> findByMeetingIdAndMemberId(Long meetingId, Long memberId);
}
