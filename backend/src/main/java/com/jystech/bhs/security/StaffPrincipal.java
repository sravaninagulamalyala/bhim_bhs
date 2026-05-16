package com.jystech.bhs.security;

import com.jystech.bhs.entity.Staff;
import lombok.Getter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;
import java.util.List;

@Getter
public class StaffPrincipal implements UserDetails {
    private final Staff staff;

    public StaffPrincipal(Staff staff) {
        this.staff = staff;
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return List.of(new SimpleGrantedAuthority("ROLE_" + staff.getRole().name()));
    }

    @Override
    public String getPassword() {
        return staff.getPassword();
    }

    @Override
    public String getUsername() {
        return staff.getAdminId();
    }

    @Override
    public boolean isEnabled() {
        return staff.isActive();
    }
}
