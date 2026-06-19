import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:preventia_belgique_app/services/billing_service.dart';

void main() {
  group('BillingService', () {
    test(
      'createCheckoutSession sends the validated PreventIA payload',
      () async {
        Uri? requestedUri;
        Map<String, dynamic>? payload;
        final service = BillingService(
          backendUrl: 'https://backend.test',
          client: MockClient((request) async {
            requestedUri = request.url;
            payload = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response(
              jsonEncode({
                'success': true,
                'checkoutUrl': 'https://checkout.test/session',
              }),
              200,
            );
          }),
        );

        final checkoutUrl = await service.createCheckoutSession(
          email: ' user@example.com ',
          password: 'password123',
          passwordConfirmation: 'password123',
          firstName: ' Alice ',
          lastName: ' Martin ',
          companyName: ' PreventIA Test ',
          vatNumber: ' BE0123456789 ',
          addressLine1: ' Rue de la Loi 1 ',
          postalCode: ' 1000 ',
          city: ' Bruxelles ',
          country: ' BE ',
          planId: 'primary_monthly',
        );

        expect(checkoutUrl, 'https://checkout.test/session');
        expect(
          requestedUri,
          Uri.parse('https://backend.test/api/billing/create-checkout-session'),
        );
        expect(payload, {
          'email': 'user@example.com',
          'password': 'password123',
          'passwordConfirmation': 'password123',
          'firstName': 'Alice',
          'lastName': 'Martin',
          'companyName': 'PreventIA Test',
          'vatNumber': 'BE0123456789',
          'addressLine1': 'Rue de la Loi 1',
          'postalCode': '1000',
          'city': 'Bruxelles',
          'country': 'BE',
          'planId': 'primary_monthly',
          'acceptTerms': true,
          'acceptPrivacy': true,
        });
        expect(payload?.containsKey('phone'), isFalse);
        expect(payload?.containsKey('telephone'), isFalse);
      },
    );
  });
}
