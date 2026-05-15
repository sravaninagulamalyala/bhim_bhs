package com.jystech.bhs.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "members_table", indexes = {
        @Index(name = "idx_member_family", columnList = "family_id"),
        @Index(name = "idx_member_mobile", columnList = "mobile_no"),
        @Index(name = "idx_member_house", columnList = "house_no")
})
public class Member extends BaseTimeEntity {
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

    @Column(name = "relation_type")
    private String relationType;

    private Integer age;

    @Column(length = 20)
    private String sex;

    @Column(name = "mobile_no", length = 20)
    private String mobileNo = "";

    @Column(name = "alternate_mobile_no", length = 20)
    private String alternateMobileNo = "";

    @Column(length = 1000)
    private String address;

    @Column(name = "house_no")
    private String houseNo;

    private String area;

    @Column(name = "caste_category", length = 20)
    private String casteCategory = "SC";

    private boolean active = true;

    @Enumerated(EnumType.STRING)
    @Column(name = "source_type", nullable = false, length = 40)
    private SourceType sourceType = SourceType.MANUAL;
}
