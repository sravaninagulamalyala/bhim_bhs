package com.jystech.bhs.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "member_registration_request")
public class MemberRegistrationRequest extends BaseTimeEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "family_id")
    private Long familyId;

    @Column(name = "first_name")
    private String firstName;

    @Column(name = "last_name")
    private String lastName;

    @Column(name = "full_name")
    private String fullName;

    @Column(name = "father_or_husband_name")
    private String fatherOrHusbandName;

    private Integer age;
    private String sex;

    @Column(name = "mobile_no")
    private String mobileNo;

    @Column(length = 1000)
    private String address;

    @Column(name = "house_no")
    private String houseNo;

    private String area;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private RegistrationStatus status = RegistrationStatus.PENDING;
}
