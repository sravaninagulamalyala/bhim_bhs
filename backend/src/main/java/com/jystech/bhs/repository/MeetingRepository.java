package com.jystech.bhs.repository;

import com.jystech.bhs.entity.Meeting;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface MeetingRepository extends JpaRepository<Meeting, Long> {
    List<Meeting> findByMeetingDate(LocalDate meetingDate);
    Optional<Meeting> findFirstByMeetingDate(LocalDate meetingDate);
    List<Meeting> findByMeetingDateBetweenOrderByMeetingDate(LocalDate start, LocalDate end);
}
