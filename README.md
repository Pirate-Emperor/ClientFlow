# ClientFlow - Flutter CRM Application

## Overview

**ClientFlow** is a comprehensive Flutter-Dart based application designed to enhance Customer Relationship Management (CRM) with a primary focus on **Sales Management**. The project aims to improve the existing web application architecture by refining the **User Experience (UX)**, integrating **real-time analytics** and dashboards, and providing **mobile compatibility**. With an interactive and user-friendly interface, this project helps businesses manage customer relations effectively, providing real-time insights into sales, customer trends, and business performance.

### Key Features:

- **Interactive Dashboards**: Real-time analytics and performance monitoring.
- **Customer Insights**: Personalized data-driven insights for better decision-making.
- **Sales Forecasting**: Predictive models for sales trends and customer behavior.
- **Mobile CRM**: A responsive mobile application, making CRM management easier on-the-go.
- **Enhanced User Experience (UX)**: Improved interface for better user interaction.
  
## Directory Structure

The project is structured as follows:

```
├─ api/
│  └─ firebase_api.dart
├─ components/
│  ├─ category_button.dart
│  ├─ item_app_bar.dart
│  ├─ item_bottom_bar.dart
│  ├─ navigation_bar.dart
│  └─ product_search_bar.dart
├─ data/
│  ├─ brand_data.dart
│  ├─ category_data.dart
│  ├─ product.dart
│  ├─ sort_list_data.dart
│  └─ sub_category_data.dart
├─ model/
│  ├─ area_select_popup.dart
│  ├─ cart_model.dart
│  ├─ custom_tab_bar.dart
│  ├─ items_widget.dart
│  └─ sort_popup.dart
├─ about_us_page.dart
├─ account_setting_page.dart
├─ background_tasks.dart
├─ brands_screen.dart
├─ cart_item.dart
├─ cart_page.dart
├─ categories_screen.dart
├─ chatbot_page.dart
├─ contact_us_page.dart
├─ create_lead_page.dart
├─ create_task_page.dart
├─ customer_details_page.dart
├─ customer_graph.dart
├─ customer_insight_graph.dart
├─ customer_insight.dart
├─ customer_insights.dart
├─ customer_list.dart
├─ customer_report_page.dart
├─ customer_sales_prediction.dart
├─ customer.dart
├─ data_analytics_page.dart
├─ db_sqlite.dart
├─ edit_item_page.dart
├─ event_logger.dart
├─ filter_categories_screen.dart
├─ firebase_options.dart
├─ home_page.dart
├─ item_screen.dart
├─ item_variations_screen.dart
├─ login_page.dart
├─ main.dart
├─ notification_page.dart
├─ order_confirmation_page.dart
├─ order_details_page.dart
├─ order_status_graph.dart
├─ order_status_report_page.dart
├─ order_submitted_page.dart
├─ predicted_product_stocks.dart
├─ product_card.dart
├─ products_screen.dart
├─ profile_page.dart
├─ recent_order_page.dart
├─ sales_forecast_graph.dart
├─ sales_lead_closed_widget.dart
├─ sales_lead_eng_widget.dart
├─ sales_lead_nego_widget.dart
├─ sales_lead_orderprocessing_widget.dart
├─ sales_order_page.dart
├─ sales_order.dart
├─ sales_report_graph.dart
├─ sales_report_page.dart
├─ search_screen.dart
├─ select_order_id.dart
├─ starting_page.dart
├─ terms_and_conditions_page.dart
├─ top_selling_product_graph.dart
├─ top_selling_product_report_page.dart
└─ utility_function.dart
```

## Features and Functionalities

### 1. API Integration
- **Firebase API** (`firebase_api.dart`): Handles communication with Firebase, enabling real-time database interactions.

### 2. Components
- **Navigation Bar** (`navigation_bar.dart`): Provides easy access to various sections of the app.
- **Product Search Bar** (`product_search_bar.dart`): Allows users to search products by name, category, and other attributes.
- **Category Button** (`category_button.dart`): Facilitates category-based navigation and product filtering.

### 3. Data Management
- **Brand and Category Data** (`brand_data.dart`, `category_data.dart`): Organizes data related to product brands and categories.
- **Product Data** (`product.dart`): Manages product information, attributes, and variations.
- **Sorting and Sub-categories** (`sort_list_data.dart`, `sub_category_data.dart`): Provides sorting functionalities and sub-category management for more refined product searches.

### 4. Customer Management
- **Customer Insights** (`customer_insight.dart`, `customer_insights.dart`): Provides personalized customer insights and predictions for better decision-making.
- **Customer Sales Predictions** (`customer_sales_prediction.dart`): Predicts customer behavior and sales potential using historical data and predictive algorithms.

### 5. Sales Management
- **Sales Forecasting** (`sales_forecast_graph.dart`): Displays real-time sales predictions to help businesses plan and strategize effectively.
- **Sales Order Management** (`sales_order_page.dart`, `sales_order.dart`): Facilitates order creation, status tracking, and detailed sales reports.

### 6. Data Analytics and Visualization
- **Real-Time Analytics** (`data_analytics_page.dart`): A dedicated page for viewing and analyzing business performance in real time.
- **Graphical Representations** (`customer_graph.dart`, `sales_report_graph.dart`, `top_selling_product_graph.dart`): Visualizes key business metrics like customer trends, top-selling products, and sales reports.

### 7. Task and Lead Management
- **Create Leads and Tasks** (`create_lead_page.dart`, `create_task_page.dart`): Provides options to create and track sales leads and customer-related tasks.

### 8. User Account and Settings
- **Profile and Account Settings** (`profile_page.dart`, `account_setting_page.dart`): Manages user profile and app-specific settings.
- **Notification Management** (`notification_page.dart`): Displays system alerts, reminders, and push notifications.

### 9. Chatbot Integration
- **Chatbot Page** (`chatbot_page.dart`): Offers an AI-powered chatbot to assist customers with inquiries, providing instant support.

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/Pirate-Emperor/clientflow.git
   ```

2. Navigate to the project directory:
   ```bash
   cd ClientFlow
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the app on your device or emulator:
   ```bash
   flutter run
   ```

## Requirements

- **Flutter SDK**: v3.0.0 or later
- **Dart SDK**: v2.17.0 or later
- **Firebase**: For real-time database integration and user authentication.
  
## Key Technologies

- **Flutter & Dart**: Cross-platform mobile development.
- **Firebase**: Real-time database and authentication.
- **SQLite**: Local database for offline data storage.
- **AI Chatbot**: For real-time customer interaction and support.

## Getting Started

1. Install the Flutter SDK from the [official website](https://flutter.dev/).
2. Set up Firebase integration following the instructions in `firebase_options.dart`.
3. Ensure you have an active Firebase project and link it with the mobile app.
4. Use `db_sqlite.dart` for setting up the local SQLite database.

## Contributing

Feel free to fork the repository, make changes, and submit pull requests. Contributions are welcome!

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Author

**Pirate-Emperor**

[![Twitter](https://skillicons.dev/icons?i=twitter)](https://twitter.com/PirateKingRahul)
[![Discord](https://skillicons.dev/icons?i=discord)](https://discord.com/users/1200728704981143634)
[![LinkedIn](https://skillicons.dev/icons?i=linkedin)](https://www.linkedin.com/in/piratekingrahul)

[![Reddit](https://img.shields.io/badge/Reddit-FF5700?style=for-the-badge&logo=reddit&logoColor=white)](https://www.reddit.com/u/PirateKingRahul)
[![Medium](https://img.shields.io/badge/Medium-42404E?style=for-the-badge&logo=medium&logoColor=white)](https://medium.com/@piratekingrahul)

- GitHub: [Pirate-Emperor](https://github.com/Pirate-Emperor)
- Reddit: [PirateKingRahul](https://www.reddit.com/u/PirateKingRahul/)
- Twitter: [PirateKingRahul](https://twitter.com/PirateKingRahul)
- Discord: [PirateKingRahul](https://discord.com/users/1200728704981143634)
- LinkedIn: [PirateKingRahul](https://www.linkedin.com/in/piratekingrahul)
- Skype: [Join Skype](https://join.skype.com/invite/yfjOJG3wv9Ki)
- Medium: [PirateKingRahul](https://medium.com/@piratekingrahul)

---

