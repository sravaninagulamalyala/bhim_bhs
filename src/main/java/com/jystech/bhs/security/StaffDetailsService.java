package com.jystech.bhs.security;

import com.jystech.bhs.repository.StaffRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class StaffDetailsService implements UserDetailsService {
    private final StaffRepository staffRepository;

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        return staffRepository.findByAdminId(username)
                .map(StaffPrincipal::new)
                .orElseThrow(() -> new UsernameNotFoundException("Invalid staff user"));
    }
}
