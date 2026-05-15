package com.jystech.bhs.audit;

import com.jystech.bhs.entity.AuditLog;
import com.jystech.bhs.repository.AuditLogRepository;
import com.jystech.bhs.security.StaffPrincipal;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuditService {
    private final AuditLogRepository auditLogRepository;
    private final HttpServletRequest request;

    public void log(String action, String moduleName, String description) {
        AuditLog log = new AuditLog();
        log.setAction(action);
        log.setModuleName(moduleName);
        log.setDescription(description);
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth != null && auth.getPrincipal() instanceof StaffPrincipal principal) {
            log.setPerformedBy(principal.getUsername());
            log.setRole(principal.getStaff().getRole().name());
        } else {
            log.setPerformedBy("PUBLIC");
        }
        log.setIpAddress(request.getRemoteAddr());
        auditLogRepository.save(log);
    }
}
