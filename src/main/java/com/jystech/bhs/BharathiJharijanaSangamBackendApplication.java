package com.jystech.bhs;

import com.jystech.bhs.entity.Staff;
import com.jystech.bhs.entity.UserRole;
import com.jystech.bhs.repository.StaffRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.security.crypto.password.PasswordEncoder;

@SpringBootApplication
@RequiredArgsConstructor
public class BharathiJharijanaSangamBackendApplication {

    public static void main(String[] args) {
        SpringApplication.run(BharathiJharijanaSangamBackendApplication.class, args);
    }

    @Bean
    CommandLineRunner seedDefaultAdmin(StaffRepository staffRepository, PasswordEncoder passwordEncoder) {
        return args -> staffRepository.findByAdminId("admin").orElseGet(() -> {
            Staff staff = new Staff();
            staff.setAdminId("admin");
            staff.setPassword(passwordEncoder.encode("welcome"));
            staff.setRole(UserRole.SUPER_ADMIN);
            staff.setActive(true);
            staff.setFullName("Default Administrator");
            staffRepository.save(staff);
            return staff;
        });
    }
}
