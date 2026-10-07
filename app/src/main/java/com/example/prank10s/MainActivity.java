package com.example.prank10s;

import android.app.Activity;
import android.os.Bundle;
import android.os.Handler;
import android.view.Window;
import android.view.WindowManager;
import android.widget.TextView;

public class MainActivity extends Activity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        requestWindowFeature(Window.FEATURE_NO_TITLE);
        getWindow().setFlags(
                WindowManager.LayoutParams.FLAG_FULLSCREEN,
                WindowManager.LayoutParams.FLAG_FULLSCREEN
        );

        TextView text = new TextView(this);
        text.setText("ТЫ ВЗЛОМАН 😈\nТЕБЕ ЖОПА");
        text.setTextSize(30);
        text.setTextColor(0xFFFF0000);
        text.setGravity(17);
        text.setBackgroundColor(0xFF000000);
        setContentView(text);

        new Handler().postDelayed(this::finish, 10000);
    }

    @Override
    public void onBackPressed() {
        // Intentionally disabled for the 10-second prank screen.
    }
}
