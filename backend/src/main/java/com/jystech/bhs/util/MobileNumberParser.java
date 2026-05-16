package com.jystech.bhs.util;

public final class MobileNumberParser {
    private MobileNumberParser() {
    }

    public static ParsedMobile parse(String mobile) {
        String value = AddressParser.clean(mobile);
        if (value.isEmpty()) {
            return new ParsedMobile("", "");
        }
        String[] parts = value.split("/", 2);
        return new ParsedMobile(parts[0].trim(), parts.length > 1 ? parts[1].trim() : "");
    }

    public record ParsedMobile(String mobileNo, String alternateMobileNo) {
    }
}
