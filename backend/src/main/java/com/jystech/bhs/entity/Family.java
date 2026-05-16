package com.jystech.bhs.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "family_table", indexes = @Index(name = "idx_family_code", columnList = "family_code", unique = true))
public class Family extends BaseTimeEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "family_code", nullable = false, unique = true)
    private String familyCode;

    @Column(name = "primary_member_id")
    private Long primaryMemberId;

    @Column(name = "house_no")
    private String houseNo;

    private String area;

    @Column(length = 1000)
    private String address;

    private boolean active = true;
}
