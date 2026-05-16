package com.jystech.bhs.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "staff_table", indexes = @Index(name = "idx_staff_admin_id", columnList = "admin_id", unique = true))
public class Staff extends BaseTimeEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "admin_id", nullable = false, unique = true, length = 80)
    private String adminId;

    @Column(nullable = false)
    @JsonIgnore
    private String password;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 40)
    private UserRole role;

    @Column(nullable = false)
    private boolean active = true;

    @Column(name = "member_id")
    private Long memberId;

    @Column(name = "full_name")
    private String fullName;

    @Column(name = "mobile_no", length = 20)
    private String mobileNo;
}
