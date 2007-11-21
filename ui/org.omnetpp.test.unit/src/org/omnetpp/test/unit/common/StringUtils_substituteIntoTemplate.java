package org.omnetpp.test.unit.common;

import java.util.HashMap;
import java.util.Map;

import junit.framework.TestCase;

import org.junit.Test;

import org.omnetpp.common.util.StringUtils;

public class StringUtils_substituteIntoTemplate extends TestCase {
    private final String TEMPLATE1 = 
        "{false:}line 1 - {foo}\n" +
        "{true:}line 2 - {foo}\n" +
        "{~true:}line 3 - {bar}\n" +
        "{~false:}line 4 - {bar}\n" +
        "line 5 {foo}{bar}.\n" +
        "line 6 {true:some-text}{~true:other-text}.\n" +
        "line 7 {false:some-text}{~false:other-text}.\n";
    private final String EXPECTED1 = 
        "line 2 - The-foo-value\n" +
        "line 4 - The-bar-value\n" +
        "line 5 The-foo-valueThe-bar-value.\n" +
        "line 6 some-text.\n" +
        "line 7 other-text.\n";

    @Test
    public void testSubstituteIntoTemplate() {
        Map<String, Object> m = new HashMap<String, Object>(); 
        m.put("true", true);
        m.put("false", false);
        m.put("foo", "The-foo-value");
        m.put("bar", "The-bar-value");
        
        check(TEMPLATE1, m, EXPECTED1);
        
    }
    
    private static void check(String template, Map<String, Object> map, String expectedOutput) {
        String actualOutput = StringUtils.substituteIntoTemplate(template, map);
        assertEquals("StringUtils.substituteIntoTemplate: wrong output for "+template, expectedOutput, actualOutput);
    }

}
