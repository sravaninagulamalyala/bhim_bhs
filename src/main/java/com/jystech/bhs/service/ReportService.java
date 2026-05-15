package com.jystech.bhs.service;

import java.io.ByteArrayInputStream;
import java.time.YearMonth;
import java.util.Map;

public interface ReportService {
    Map<String, Object> familyMemberCount();
    Map<String, Object> monthlyContribution(YearMonth month);
    Map<String, Object> contributedFamilies(YearMonth month);
    Map<String, Object> nonContributedFamilies(YearMonth month);
    Map<String, Object> heatmap(YearMonth month);
    ByteArrayInputStream download(String type, YearMonth month);
}
