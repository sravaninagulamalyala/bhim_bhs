package com.jystech.bhs.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter
@Setter
@Entity
@Table(name = "attendance_table", uniqueConstraints = @UniqueConstraint(name = "uk_attendance_meeting_member", columnNames = {"meeting_id", "member_id"}))
public class Attendance {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "meeting_id", nullable = false)
    private Long meetingId;

    @Column(name = "member_id", nullable = false)
    private Long memberId;

    @Column(name = "family_id")
    private Long familyId;

    private boolean attended;

    @Column(name = "marked_by")
    private String markedBy;

    @Column(name = "marked_at")
    private LocalDateTime markedAt = LocalDateTime.now();

    @Column(name = "updated_by")
    private String updatedBy;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @Column(nullable = false, columnDefinition = "boolean default true")
    private boolean active = true;
}
