package com.jystech.bhs.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDateTime;

@Getter
@Setter
@Entity
@Table(name = "audit_log_table")
public class AuditLog {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String action;

    @Column(name = "module_name")
    private String moduleName;

    @Column(length = 1500)
    private String description;

    @Column(name = "performed_by")
    private String performedBy;

    private String role;

    @Column(name = "ip_address")
    private String ipAddress;

    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();
}
